# Next Steps

The transformation appears to have completed successfully. There are no build errors present in the solution. Below are steps to validate, test, and deploy your migrated project.

## 1. Verify Target Framework

Open `AdoCore.csproj` and confirm the target framework is set to the intended cross-platform version, for example:

```xml
<TargetFramework>net8.0</TargetFramework>
```

Ensure this aligns with the .NET version installed on your machine by running:

```bash
dotnet --version
```

## 2. Restore Dependencies

Run a NuGet package restore to ensure all dependencies are resolved correctly:

```bash
dotnet restore
```

Review the output for any warnings about deprecated or unlisted packages and consider updating them using:

```bash
dotnet list package --outdated
dotnet add package <PackageName>
```

## 3. Build the Solution

Perform a full build to confirm there are no compilation issues:

```bash
dotnet build --configuration Release
```

Review the build output for any warnings that may indicate compatibility concerns, even if they do not prevent compilation.

## 4. Run Existing Tests

If the solution contains test projects, execute them to verify that existing functionality is preserved:

```bash
dotnet test --configuration Release
```

Review the test results carefully. Any failing tests should be investigated to determine if they are caused by behavioral differences between the legacy .NET Framework and the new cross-platform .NET runtime.

## 5. Check for Platform-Specific API Usage

Review the code for any APIs that were available in .NET Framework but are absent or behave differently in cross-platform .NET. Common areas to check include:

- `System.Web` references (not available in .NET Core/.NET 5+)
- Windows Registry access (`Microsoft.Win32.Registry`)
- WCF server-side components
- `AppDomain` usage
- `BinaryFormatter` (deprecated and disabled by default)

Use the [.NET Upgrade Assistant compatibility analyzer](https://learn.microsoft.com/en-us/dotnet/core/porting/upgrade-assistant-overview) or the `Microsoft.DotNet.PlatformAbstractions` tooling to identify remaining compatibility issues.

## 6. Run the Application

Execute the application directly to perform a basic smoke test:

```bash
dotnet run --project AdoCore.csproj --configuration Release
```

Verify that the application starts without runtime exceptions and that core functionality behaves as expected.

## 7. Test on Target Platforms

Since the goal is cross-platform support, run and validate the application on each intended operating system (Windows, Linux, macOS) to surface any platform-specific runtime issues that would not appear during a build.

## 8. Publish the Application

Once validation is complete, publish a self-contained or framework-dependent release build:

**Framework-dependent:**
```bash
dotnet publish -c Release -o ./publish
```

**Self-contained (example for Linux x64):**
```bash
dotnet publish -c Release -r linux-x64 --self-contained true -o ./publish
```

Review the contents of the `./publish` directory and verify all required assets and configuration files are present before deploying to the target environment.