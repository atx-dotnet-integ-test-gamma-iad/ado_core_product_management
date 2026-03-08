# Next Steps

The transformation appears to have completed successfully. No build errors were detected across any of the projects in the solution. Below are recommended steps to validate and deploy your migrated project.

## 1. Restore Dependencies

Run the following command to ensure all NuGet packages are properly restored:

```bash
dotnet restore
```

Review the output for any warnings related to deprecated packages or version conflicts. If any packages targeting the old .NET Framework are still present, check for their cross-platform equivalents on [NuGet.org](https://www.nuget.org).

## 2. Build the Solution

Perform a full build to confirm there are no issues beyond what was reported:

```bash
dotnet build --configuration Release
```

Review any warnings in the build output, as some warnings may indicate compatibility concerns that do not prevent compilation but could cause runtime issues.

## 3. Run Unit Tests

If the solution contains test projects, execute them to verify that existing functionality behaves as expected after migration:

```bash
dotnet test --configuration Release
```

Review test results carefully. Any failing tests should be investigated to determine whether they indicate a regression introduced during migration or a pre-existing issue.

## 4. Verify Platform-Specific Code

Review the codebase for any APIs that were available in .NET Framework but may behave differently or be unavailable in cross-platform .NET. Common areas to check include:

- `System.Windows.Forms` or `System.Web` usage (not supported cross-platform)
- Registry access (`Microsoft.Win32.Registry`)
- Windows-specific file path assumptions (e.g., backslashes, drive letters)
- `AppDomain` usage, which has partial support in modern .NET
- Any P/Invoke calls targeting Windows-only native libraries

Use the [.NET Upgrade Assistant compatibility analyzer](https://learn.microsoft.com/en-us/dotnet/core/porting/upgrade-assistant-overview) or the [Platform Compatibility Analyzer](https://learn.microsoft.com/en-us/dotnet/standard/analyzers/platform-compat-analyzer) to assist with this review.

## 5. Test on Target Platforms

If cross-platform support is a goal, run and test the application on each intended operating system (e.g., Windows, Linux, macOS):

```bash
dotnet run --configuration Release
```

Pay attention to differences in file system case sensitivity, path separators, and environment variable behavior between operating systems.

## 6. Publish the Application

Once validation is complete, publish the application for your target runtime. For a self-contained deployment targeting Linux x64 as an example:

```bash
dotnet publish --configuration Release --runtime linux-x64 --self-contained true
```

For a framework-dependent deployment:

```bash
dotnet publish --configuration Release
```

Review the contents of the `publish` output directory to confirm all required assets and dependencies are present before deploying to the target environment.