# Next Steps

The transformation appears to have completed successfully. No build errors were detected across any of the projects in the solution. Below are recommended steps to validate and deploy your migrated project.

## 1. Restore Dependencies

Run the following command to ensure all NuGet packages are properly restored:

```bash
dotnet restore
```

Review the output for any warnings related to package compatibility or deprecated packages targeting older frameworks.

## 2. Build the Solution

Perform a full solution build to confirm the absence of errors in a clean build environment:

```bash
dotnet build --configuration Release
```

Address any warnings that surface during this step, particularly those related to nullable reference types or obsolete APIs, as these can indicate subtle compatibility issues.

## 3. Run Existing Tests

If the solution contains test projects, execute the full test suite to verify behavioral correctness after migration:

```bash
dotnet test --configuration Release
```

Review any failing tests carefully. Failures after a migration often point to platform-specific behavior differences between .NET Framework and cross-platform .NET.

## 4. Verify Platform-Specific Code

Manually review the codebase for any APIs that were available in .NET Framework but have limited or no support in cross-platform .NET. Common areas to check include:

- `System.Web` usage
- Windows Registry access (`Microsoft.Win32.Registry`)
- `AppDomain` usage beyond what is supported
- WCF server-side components
- Remoting (`System.Runtime.Remoting`)
- Binary serialization (`BinaryFormatter`)

Use the [.NET Upgrade Assistant compatibility analyzer](https://learn.microsoft.com/en-us/dotnet/core/porting/upgrade-assistant-overview) or the `Microsoft.DotNet.PlatformAbstractions` tooling to assist with this review.

## 5. Test on Target Platforms

Since the goal is cross-platform support, run and validate the application on each intended target operating system (e.g., Windows, Linux, macOS):

```bash
dotnet run --configuration Release
```

Pay particular attention to:
- File path separators (`/` vs `\`)
- Case sensitivity in file system operations
- Environment variable differences across operating systems
- Line ending differences (`\r\n` vs `\n`)

## 6. Publish the Application

Once validation is complete, publish the application for your target runtime. For a self-contained deployment targeting Linux x64 as an example:

```bash
dotnet publish --configuration Release --runtime linux-x64 --self-contained true
```

For a framework-dependent deployment:

```bash
dotnet publish --configuration Release
```

Review the output directory to confirm all required assets and dependencies are present before deploying to the target environment.