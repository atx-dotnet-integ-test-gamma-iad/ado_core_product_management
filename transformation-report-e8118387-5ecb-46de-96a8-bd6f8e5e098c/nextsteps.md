# Next Steps

The transformation appears to have completed successfully. There are no build errors present in the solution. Below are steps to validate, test, and deploy your migrated project.

## 1. Verify Target Framework

Open `AdoCore.csproj` and confirm the target framework is set to the intended cross-platform .NET version (e.g., `net6.0`, `net7.0`, or `net8.0`):

```xml
<PropertyGroup>
  <TargetFramework>net8.0</TargetFramework>
</PropertyGroup>
```

## 2. Restore Dependencies

Run a NuGet restore to ensure all packages are resolved correctly:

```bash
dotnet restore
```

Review the output for any warnings about deprecated or unlisted packages that may need to be updated.

## 3. Build the Solution

Perform a full build in Release configuration to confirm there are no configuration-specific issues:

```bash
dotnet build --configuration Release
```

## 4. Run Existing Tests

If the solution contains test projects, execute them to verify that existing functionality has not regressed:

```bash
dotnet test --configuration Release
```

Review the test output for any failures or skipped tests that may indicate platform-specific behavior that needs to be addressed.

## 5. Check for Platform-Specific API Usage

Review the code for any APIs that were available in .NET Framework but are not available or behave differently in cross-platform .NET. Common areas to check include:

- `System.Windows.Forms` or `System.Web` references (not available cross-platform)
- Registry access (`Microsoft.Win32.Registry`)
- Windows-specific file path assumptions (e.g., backslashes, drive letters)
- `AppDomain` usage, as some members are no longer supported
- Any P/Invoke calls targeting Windows-only native libraries

## 6. Review NuGet Package Compatibility

Check that all referenced NuGet packages support the target framework. You can use the following command to identify outdated packages:

```bash
dotnet list package --outdated
```

Update packages where necessary using:

```bash
dotnet add package <PackageName>
```

## 7. Run the Application

Execute the application directly to verify runtime behavior:

```bash
dotnet run --configuration Release
```

Test the primary workflows and features of the application to confirm they function as expected on the new runtime.

## 8. Test on Target Platforms

If cross-platform support is a goal, run the application on each intended operating system (Windows, Linux, macOS) to identify any platform-specific runtime issues that would not surface during a build.

## 9. Review Output Artifacts

Publish the application to verify the output is correct:

```bash
dotnet publish --configuration Release --output ./publish
```

Inspect the `./publish` directory to confirm all required files and dependencies are present.