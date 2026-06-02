# Next Steps

The transformation appears to have completed successfully. There are no build errors reported across any of the projects in the solution. Below are steps to validate, test, and deploy your migrated project.

## 1. Verify Target Framework

Open each `.csproj` file and confirm the `<TargetFramework>` (or `<TargetFrameworks>`) element is set to the intended cross-platform .NET version, for example:

```xml
<TargetFramework>net8.0</TargetFramework>
```

Ensure no projects are still referencing `net48` or any other legacy .NET Framework moniker unless that is intentional.

## 2. Restore NuGet Packages

Run the following command from the solution root to ensure all dependencies are restored cleanly:

```bash
dotnet restore
```

Review the output for any warnings about deprecated packages or packages that do not support the target framework.

## 3. Build the Solution

Perform a full build to confirm there are no errors or warnings that may have been missed:

```bash
dotnet build --configuration Release
```

Address any warnings that surface, particularly those related to nullable reference types, obsolete APIs, or platform compatibility.

## 4. Run Existing Tests

If the solution contains test projects, execute them to verify that existing behavior is preserved:

```bash
dotnet test --configuration Release
```

Review any failing tests carefully. Failures may indicate behavioral differences between .NET Framework and cross-platform .NET, such as changes in globalization, threading, or reflection behavior.

## 5. Check for Platform-Specific API Usage

Use the .NET Compatibility Analyzer or review the code manually for APIs that were available in .NET Framework but are absent or behave differently in cross-platform .NET. Common areas to check include:

- `System.Web` references (not available outside of ASP.NET Core)
- Windows Registry access (`Microsoft.Win32.Registry`)
- WCF server-side components
- `AppDomain` usage
- `BinaryFormatter` (deprecated and disabled by default)

Run the following to surface compatibility warnings during build:

```bash
dotnet build -p:EnableNETAnalyzers=true
```

## 6. Validate Runtime Behavior

Run the application on each target platform (Windows, Linux, macOS) if cross-platform support is a goal. Pay attention to:

- File path separators (`/` vs `\`)
- Case sensitivity in file system operations
- Environment variable differences
- Culture and encoding defaults

## 7. Review Configuration Files

Confirm that any `app.config` or `web.config` files have been migrated to the appropriate `appsettings.json` or other .NET configuration mechanisms. Legacy XML configuration sections are not automatically carried over.

## 8. Publish the Application

Once validation is complete, publish the application using:

```bash
dotnet publish --configuration Release --output ./publish
```

For a self-contained deployment that does not require the .NET runtime to be installed on the target machine:

```bash
dotnet publish --configuration Release --self-contained true --runtime linux-x64 --output ./publish
```

Replace `linux-x64` with the appropriate runtime identifier for your target environment (`win-x64`, `osx-x64`, etc.).

## 9. Verify the Published Output

Navigate to the publish output directory and run the application to confirm it starts and operates correctly in the published form before distributing or deploying it.